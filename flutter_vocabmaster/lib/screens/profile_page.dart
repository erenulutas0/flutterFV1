import 'package:flutter/material.dart';
import '../widgets/animated_background.dart';
import '../widgets/bottom_nav.dart';
import '../main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _selectedTheme = 'Buz Mavisi';

  // State for notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _achievementNotifications = true;
  bool _friendRequestNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      // AppBar'ı kaldırdık, böylece özel header scroll ile birlikte hareket edecek
      body: Stack(
        children: [
          // Yağış animasyonu en arkada ve tüm ekranı kaplıyor
          const Positioned.fill(
            child: AnimatedBackground(isDark: true),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  _buildCustomHeader(context),
                  const SizedBox(height: 20),
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildThemeSelection(),
                  const SizedBox(height: 24),
                  _buildAccountSettings(),
                  const SizedBox(height: 24),
                  _buildFriendsSection(),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: -1, 
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(initialIndex: index),
            ),
            (route) => false,
          );
        },
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title'ı ortalamak için solda görünmez bir buton
        const IconButton(
          onPressed: null,
          icon: Icon(Icons.close, color: Colors.transparent),
        ),
        const Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1e3a8a).withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  image: const DecorationImage(
                    image: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Eren'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0ea5e9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '5',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Eren',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'eren@vocabmaster.com',
            style: TextStyle(
              color: const Color(0xFF38bdf8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0369a1).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Ocak 2025 tarihinden beri üye',
              style: TextStyle(color: Color(0xFF7dd3fc), fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.verified_user_outlined, size: 18),
            label: const Text('Hesabı Doğrula'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10b981),
              side: const BorderSide(color: Color(0xFF10b981)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'XP İlerlemesi',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '450 / 600',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 450 / 600,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3b82f6)),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sonraki seviyeye 150 XP kaldı',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStatItem(Icons.emoji_events_outlined, '124', 'Toplam\nKelime', const Color(0xFF0ea5e9))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatItem(Icons.calendar_today_outlined, '7', 'Gün Serisi', const Color(0xFF0ea5e9))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatItem(Icons.military_tech_outlined, '12', 'Başarılar', const Color(0xFF0ea5e9))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1e3a8a).withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF0ea5e9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.palette_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tema Seçimi',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Uygulamanın rengini özelleştirin',
                    style: TextStyle(color: const Color(0xFF38bdf8), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildThemeOption('Buz Mavisi', const Color(0xFF0284c7), true),
              _buildThemeOption('Mor', const Color(0xFF7c3aed), false, isComingSoon: true),
              _buildThemeOption('Yeşil', const Color(0xFF059669), false, isComingSoon: true),
              _buildThemeOption('Turuncu', const Color(0xFFea580c), false, isComingSoon: true),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0ea5e9).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.palette, color: Color(0xFF0ea5e9), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      children: [
                        const TextSpan(text: 'Şu an '),
                        TextSpan(
                          text: _selectedTheme,
                          style: const TextStyle(color: Color(0xFF0ea5e9), fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' teması kullanılıyor'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String name, Color color, bool isSelected, {bool isComingSoon = false}) {
    return GestureDetector(
      onTap: isComingSoon ? null : () => setState(() => _selectedTheme = name),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0ea5e9) : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF0ea5e9).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (isComingSoon)
                Container(
                  color: Colors.black.withOpacity(0.6),
                  child: const Center(
                    child: Text(
                      'Yakında',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1e3a8a).withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: Color(0xFF0ea5e9), size: 24),
              SizedBox(width: 12),
              Text(
                'Hesap Ayarları',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsTile(Icons.person_outline, 'Profili Düzenle', _showEditProfileDialog),
          const SizedBox(height: 12),
          _buildSettingsTile(Icons.notifications_none, 'Bildirim Tercihleri', _showNotificationSettingsDialog),
          const SizedBox(height: 12),
          _buildSettingsTile(Icons.lock_outline, 'Gizlilik Ayarları', _showPrivacySettingsDialog),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF38bdf8), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }

  // Dialog Implementation
  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1e1b4b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     const Row(
                       children: [
                         Icon(Icons.person_outline, color: Color(0xFF0ea5e9), size: 24),
                         SizedBox(width: 12),
                         Text(
                           'Profili Düzenle',
                           style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                         ),
                       ],
                     ),
                     IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLabel('İsim'),
                _buildDarkTextField(initialValue: 'Eren'),
                const SizedBox(height: 16),
                _buildLabel('Email'),
                _buildDarkTextField(initialValue: 'eren@vocabmaster.com'),
                 const SizedBox(height: 16),
                _buildLabel('Bio'),
                _buildDarkTextField(hint: 'Kendinizi tanıtın...', maxLines: 4),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0072ff),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Değişiklikleri Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          backgroundColor: const Color(0xFF1e1b4b),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Expanded(
                         child: Row(
                           children: [
                             Icon(Icons.notifications_active_outlined, color: Color(0xFF0ea5e9), size: 24),
                             SizedBox(width: 12),
                             Flexible(
                               child: Text(
                                 'Bildirim Tercihleri',
                                 style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                           ],
                         ),
                       ),
                       IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSwitchTile('Push Bildirimleri', 'Yeni mesajlar ve güncellemeler', _pushNotifications, (v) => setStateDialog(() => _pushNotifications = v)),
                  const SizedBox(height: 12),
                   _buildSwitchTile('Email Bildirimleri', 'Haftalık özet ve önemli bilgiler', _emailNotifications, (v) => setStateDialog(() => _emailNotifications = v)),
                   const SizedBox(height: 12),
                    _buildSwitchTile('Başarım Bildirimleri', 'Yeni rozetler ve seviye atlamalar', _achievementNotifications, (v) => setStateDialog(() => _achievementNotifications = v)),
                    const SizedBox(height: 12),
                     _buildSwitchTile('Arkadaş İstekleri', 'Yeni arkadaşlık istekleri', _friendRequestNotifications, (v) => setStateDialog(() => _friendRequestNotifications = v)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacySettingsDialog() {
     showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1e1b4b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Expanded(
                         child: Row(
                           children: [
                             Icon(Icons.lock_outline, color: Color(0xFF0ea5e9), size: 24),
                             SizedBox(width: 12),
                             Flexible(
                               child: Text(
                                 'Gizlilik Ayarları',
                                 style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                           ],
                         ),
                       ),
                       IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildPrivacyTile(Icons.person_outline, 'Profil Görünürlüğü', 'Herkes'),
                   const SizedBox(height: 12),
                   _buildPrivacyTile(Icons.verified_user_outlined, 'Aktivite Durumu', 'Çevrimiçi/Çevrimdışı göster'),
                    const SizedBox(height: 12),
                    _buildPrivacyTile(Icons.people_outline, 'Arkadaş İstekleri', 'Herkesten kabul et'),
                     const SizedBox(height: 12),
                     _buildPrivacyTile(Icons.lock_open, 'Mesajlar', 'Sadece arkadaşlar'),
              ],
            ),
          ),
        ),
      ),
     );
  }
  
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildDarkTextField({String? initialValue, String? hint, int maxLines = 1}) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
         color: Colors.white.withOpacity(0.05),
         borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: const Color(0xFF06b6d4).withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value, 
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF0072ff),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTile(IconData icon, String title, String subtitle) {
     return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
         color: Colors.white.withOpacity(0.05),
         borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF06b6d4), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 Text(subtitle, style: TextStyle(color: const Color(0xFF06b6d4).withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
        ],
      ),
     );
  }

  Widget _buildFriendsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1e3a8a).withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.people_outline, color: Color(0xFF0ea5e9), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Arkadaşlar',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: const Color(0xFF059669).withOpacity(0.2),
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: const Color(0xFF059669)),
                 ),
                 child: const Text('3 Çevrimiçi', style: TextStyle(color: Color(0xFF34d399), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Text(
            'ÇEVRİMİÇİ',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFriendItem('Ayşe K.', 'Seviye 8', true, '👩', 1),
          const SizedBox(height: 12),
          _buildFriendItem('Mehmet Y.', 'Seviye 12', true, '👨', 2),
           const SizedBox(height: 12),
          _buildFriendItem('Sarah J.', 'Seviye 6', true, '👱‍♀️', 3),

          const SizedBox(height: 24),
           Text(
            'ÇEVRİMDIŞI',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFriendItem('Carlos M.', '2 saat önce', false, '👨‍🦱', 4),
          const SizedBox(height: 12),
          _buildFriendItem('Emma T.', '1 gün önce', false, '👩‍🦰', 5),
          const SizedBox(height: 12),
          _buildFriendItem('David L.', '3 gün önce', false, '👴', 6),
        ],
      ),
    );
  }

  Widget _buildFriendItem(String name, String status, bool isOnline, String avatar, int seed) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFF0ea5e9) : Colors.grey[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(avatar, style: const TextStyle(fontSize: 24))),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF22c55e) : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1e1b4b), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: isOnline ? const Color(0xFF38bdf8) : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4c1d95).withOpacity(0.5),
          foregroundColor: const Color(0xFFe879f9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF4c1d95)),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Çıkış Yap',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
