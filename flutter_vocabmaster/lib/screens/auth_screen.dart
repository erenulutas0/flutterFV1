import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/animated_background.dart';
import '../main.dart';
import '../config/backend_config.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isOnline = true;
  bool _isCheckingSession = true;
  String? _errorMessage;
  String? _cachedEmail; // Son giriş yapan kullanıcının emaili

  // Controllers
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    // Check connectivity and session
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _checkConnectivity();
    await _checkExistingSession();
    
    if (mounted) {
      setState(() => _isCheckingSession = false);
      _animController.forward();
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _isOnline = !result.contains(ConnectivityResult.none);
      
      // Gerçek internet erişimi kontrolü
      if (_isOnline) {
        try {
          final response = await http.get(
            Uri.parse('${BackendConfig.baseUrl}/api/health'),
          ).timeout(const Duration(seconds: 3));
          _isOnline = response.statusCode == 200;
        } catch (e) {
          _isOnline = false;
        }
      }
    } catch (e) {
      _isOnline = false;
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('session_token');
    final userData = prefs.getString('user_data');
    
    // Son kullanıcı emaili al
    if (userData != null) {
      try {
        final user = jsonDecode(userData);
        _cachedEmail = user['email'];
        _emailController.text = _cachedEmail ?? '';
      } catch (e) {
        // ignore
      }
    }
    
    if (token != null && userData != null) {
      if (_isOnline) {
        // Online: Token'ı doğrula
        try {
          final response = await http.get(
            Uri.parse('${BackendConfig.baseUrl}/api/auth/validate'),
            headers: {'Authorization': 'Bearer $token'},
          ).timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['valid'] == true) {
              _navigateToMain();
              return;
            }
          }
        } catch (e) {
          // Token doğrulama hatası - offline moduna geç
          print('Token validation failed, trying offline mode: $e');
          _navigateToMain(); // Cached data ile devam et
          return;
        }
      } else {
        // Offline: Cached session varsa direkt giriş yap
        print('📴 Offline mod: Cached session ile otomatik giriş');
        _navigateToMain();
        return;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    if (!_isOnline) {
      // Offline'da kayıt olamaz
      setState(() {
        _errorMessage = 'Kayıt olmak için internet bağlantısı gerekli';
      });
      return;
    }
    
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
    _animController.reset();
    _animController.forward();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        if (_isOnline) {
          await _login();
        } else {
          await _offlineLogin();
        }
      } else {
        if (_isOnline) {
          await _register();
        } else {
          throw Exception('Kayıt olmak için internet bağlantısı gerekli');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    final response = await http.post(
      Uri.parse('${BackendConfig.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'emailOrTag': _emailController.text.trim(),
        'password': _passwordController.text,
        'deviceInfo': 'Flutter Mobile App',
      }),
    );

    final data = jsonDecode(response.body);
    
    if (data['success'] == true) {
      await _saveSession(data);
      // Şifreyi de kaydet (offline login için)
      await _saveOfflineCredentials(_emailController.text.trim(), _passwordController.text);
      _navigateToMain();
    } else {
      throw Exception(data['error'] ?? 'Giriş başarısız');
    }
  }

  Future<void> _offlineLogin() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Cached credentials kontrol et
    final cachedEmail = prefs.getString('offline_email');
    final cachedPasswordHash = prefs.getString('offline_password_hash');
    final cachedUserData = prefs.getString('user_data');
    
    if (cachedEmail == null || cachedPasswordHash == null || cachedUserData == null) {
      throw Exception('Offline giriş için önce online giriş yapmalısınız');
    }
    
    final inputEmail = _emailController.text.trim().toLowerCase();
    final inputPasswordHash = _hashPassword(_passwordController.text);
    
    if (inputEmail != cachedEmail.toLowerCase()) {
      throw Exception('Bu email için offline bilgi bulunamadı');
    }
    
    if (inputPasswordHash != cachedPasswordHash) {
      throw Exception('Şifre yanlış');
    }
    
    // Offline login başarılı
    print('✅ Offline giriş başarılı');
    _navigateToMain();
  }

  Future<void> _saveOfflineCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_email', email.toLowerCase());
    await prefs.setString('offline_password_hash', _hashPassword(password));
  }

  String _hashPassword(String password) {
    // Basit hash - gerçek uygulamada daha güvenli bir yöntem kullanılmalı
    var hash = 0;
    for (var i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash) + password.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF; // Convert to 32bit integer
    }
    return hash.toString();
  }

  Future<void> _register() async {
    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      throw Exception('Şifreler eşleşmiyor');
    }

    if (_passwordController.text.length < 6) {
      throw Exception('Şifre en az 6 karakter olmalı');
    }

    if (_displayNameController.text.trim().isEmpty) {
      throw Exception('İsim gerekli');
    }

    final response = await http.post(
      Uri.parse('${BackendConfig.baseUrl}/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'displayName': _displayNameController.text.trim(),
        'password': _passwordController.text,
        'deviceInfo': 'Flutter Mobile App',
      }),
    );

    final data = jsonDecode(response.body);
    
    if (data['success'] == true) {
      await _saveSession(data);
      await _saveOfflineCredentials(_emailController.text.trim(), _passwordController.text);
      _showWelcomeDialog(data['user']);
    } else {
      throw Exception(data['error'] ?? 'Kayıt başarısız');
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_token', data['sessionToken']);
    await prefs.setString('user_data', jsonEncode(data['user']));
  }

  void _showWelcomeDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 60, color: Color(0xFF06b6d4)),
            const SizedBox(height: 16),
            Text(
              'Hoş Geldin, ${user['displayName']}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user['userTag'] ?? '#00000',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu senin benzersiz kullanıcı ID\'n.\nArkadaşların seni bu ID ile bulabilir!',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToMain();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06b6d4),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Başlayalım!', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Session kontrol ediliyor
    if (_isCheckingSession) {
      return Scaffold(
        backgroundColor: const Color(0xFF111827),
        body: Stack(
          children: [
            const Positioned.fill(
              child: AnimatedBackground(isDark: true),
            ),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF06b6d4)),
                  SizedBox(height: 16),
                  Text(
                    'Oturum kontrol ediliyor...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Stack(
        children: [
          // Background
          const Positioned.fill(
            child: AnimatedBackground(isDark: true),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // Logo/Title
                    _buildHeader(),

                    const SizedBox(height: 40),

                    // Offline Mode Indicator
                    if (!_isOnline) _buildOfflineIndicator(),

                    // Form Card
                    _buildFormCard(),

                    const SizedBox(height: 24),

                    // Toggle Login/Register
                    _buildToggleButton(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Çevrimdışı Mod',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _cachedEmail != null
                      ? 'Son giriş: $_cachedEmail'
                      : 'Daha önce giriş yapmadınız',
                  style: TextStyle(
                    color: Colors.amber.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06b6d4).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.school, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'Tekrar Hoş Geldin!' : 'Hesap Oluştur',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin 
            ? (_isOnline 
                ? 'Email veya kullanıcı ID\'n ile giriş yap'
                : 'Offline modda son hesabınla giriş yap')
            : 'VocabMaster\'a katıl ve öğrenmeye başla',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Error Message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Display Name (Register only)
          if (!_isLogin) ...[
            _buildTextField(
              controller: _displayNameController,
              label: 'İsim',
              hint: 'Görünecek isminiz',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
          ],

          // Email
          _buildTextField(
            controller: _emailController,
            label: _isLogin ? 'Email veya Kullanıcı ID' : 'Email',
            hint: _isLogin ? 'ornek@email.com veya #12345' : 'ornek@email.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          // Password
          _buildTextField(
            controller: _passwordController,
            label: 'Şifre',
            hint: '••••••••',
            icon: Icons.lock,
            isPassword: true,
          ),

          // Confirm Password (Register only)
          if (!_isLogin) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Şifre Tekrar',
              hint: '••••••••',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
          ],

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isOnline 
                    ? const Color(0xFF06b6d4)
                    : Colors.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: (_isOnline 
                    ? const Color(0xFF06b6d4)
                    : Colors.amber).withOpacity(0.4),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isOnline) ...[
                          const Icon(Icons.wifi_off, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _isLogin 
                              ? (_isOnline ? 'Giriş Yap' : 'Offline Giriş')
                              : 'Kayıt Ol',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(icon, color: const Color(0xFF06b6d4), size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF06b6d4)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? 'Hesabın yok mu?' : 'Zaten hesabın var mı?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        TextButton(
          onPressed: _toggleMode,
          child: Text(
            _isLogin ? 'Kayıt Ol' : 'Giriş Yap',
            style: TextStyle(
              color: _isOnline ? const Color(0xFF06b6d4) : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
