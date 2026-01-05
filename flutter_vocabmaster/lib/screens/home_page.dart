import 'package:flutter/material.dart';
import '../widgets/animated_background.dart';
import '../services/api_service.dart';
import '../models/word.dart';
import '../widgets/info_dialog.dart';
import 'chat_list_page.dart';
import 'chat_detail_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final Function(String) onNavigate;

  const HomePage({
    Key? key,
    required this.onNavigate,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showInstructions = false;
  bool isLoading = true;
  final ApiService _apiService = ApiService();

  // User data
  Map<String, dynamic> user = {
    'name': 'Kullanıcı',
    'level': 1,
    'xp': 0,
    'xpToNextLevel': 100,
    'totalWords': 0,
    'streak': 0,
    'weeklyXP': 0,
    'dailyGoal': 5,
    'learnedToday': 0,
  };

  List<Map<String, dynamic>> calendar = [
    {'day': 'Mon', 'learned': false, 'count': 0},
    {'day': 'Tue', 'learned': false, 'count': 0},
    {'day': 'Wed', 'learned': false, 'count': 0},
    {'day': 'Thu', 'learned': false, 'count': 0},
    {'day': 'Fri', 'learned': false, 'count': 0},
    {'day': 'Sat', 'learned': false, 'count': 0},
    {'day': 'Sun', 'learned': false, 'count': 0},
  ];

  final List<Map<String, dynamic>> onlineUsers = [
    {'id': 1, 'name': 'Ayşe K.', 'level': 8, 'status': 'online', 'avatar': '👩'},
    {'id': 2, 'name': 'Mehmet Y.', 'level': 12, 'status': 'online', 'avatar': '👨'},
    {'id': 3, 'name': 'Sarah J.', 'level': 6, 'status': 'online', 'avatar': '👱‍♀️'},
    {'id': 4, 'name': 'Carlos M.', 'level': 10, 'status': 'online', 'avatar': '👨‍🦱'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final allWords = await _apiService.getAllWords();
      final totalWords = allWords.length;
      final xp = totalWords * 10;
      final level = (xp / 100).floor() + 1;
      
      // Calculate learned today
      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T')[0];
      final learnedToday = allWords.where((w) => 
        w.learnedDate.toIso8601String().split('T')[0] == todayStr
      ).length;

      // Calculate streak
      final dates = (await _apiService.getAllDistinctDates()).toSet();
      int streak = 0;
      DateTime date = now;
      while (true) {
        final dStr = date.toIso8601String().split('T')[0];
        if (dates.contains(dStr)) {
          streak++;
          date = date.subtract(const Duration(days: 1));
        } else {
          // If today is 0, checking yesterday might continue the streak?
          // For simplicity, strict streak: if today/yesterday missed, it breaks.
          if (dStr == todayStr && streak == 0) {
             date = date.subtract(const Duration(days: 1));
             continue; // Allow skipping today if checking late at night and haven't done it yet
          }
          break;
        }
      }

      // Calculate weekly activity
      final List<Map<String, dynamic>> newCalendar = [];
      // Start from Monday of current week? Or last 7 days? 
      // UI shows Mon-Sun. Let's find this week's Monday.
      
      // Find Monday
      DateTime monday = now.subtract(Duration(days: now.weekday - 1));
      int weeklyWords = 0;

      for (int i = 0; i < 7; i++) {
        final dayDate = monday.add(Duration(days: i));
        final dayStr = dayDate.toIso8601String().split('T')[0];
        final count = allWords.where((w) => 
          w.learnedDate.toIso8601String().split('T')[0] == dayStr
        ).length;
        
        weeklyWords += count;
        
        final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i];
        
        newCalendar.add({
          'day': dayName,
          'learned': count > 0,
          'count': count,
        });
      }

      final weeklyXP = weeklyWords * 10;

      if (mounted) {
        setState(() {
          user = {
            'name': 'Kullanıcı', // Could fetch from profile if available
            'level': level,
            'xp': xp,
            'xpToNextLevel': level * 100, // naive next level
            'totalWords': totalWords,
            'streak': streak,
            'weeklyXP': weeklyXP,
            'dailyGoal': 5,
            'learnedToday': learnedToday,
          };
          calendar = newCalendar;
          isLoading = false;
        });
      }

    } catch (e) {
      print('Error loading stats: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(isDark: true),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top Section
                  _buildTopSection(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Stats Cards
                        _buildStatsCards(),
                        const SizedBox(height: 24),
                        // Daily Goal
                        _buildDailyGoal(),
                        const SizedBox(height: 24),
                        // Weekly Calendar
                        _buildWeeklyCalendar(),
                        const SizedBox(height: 24),
                        // Quick Actions
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        // Online Users
                        _buildOnlineUsers(),
                        const SizedBox(height: 24),
                        // Recently Learned
                        _buildRecentlyLearned(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture and Level
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://api.dicebear.com/7.x/avataaars/png?seed=Eren',
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: Icon(Icons.person, size: 40, color: Color(0xFF3b82f6)),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 40, color: Color(0xFF3b82f6));
                          },
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      'Seviye ${user['level']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // User Info & XP Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Welcome, Eren',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        InfoDialog.show(
                          context,
                          title: 'VocabMaster\'a Hoş Geldiniz',
                          steps: [
                            'Günlük hedefinizi takip edin ve her gün en az 5 kelime öğrenmeyi hedefleyin.',
                            'Seriyi kırmayın! Ardışık günlerde çalışarak streak puanınızı artırın.',
                            'XP kazanarak seviye atlayın ve yeni başarılar kazanın.',
                            'Öğrendiğiniz kelimeleri pratik, okuma ve konuşma aktiviteleriyle pekiştirin.',
                            'İstatistikler sayfasından ilerlemenizi detaylı olarak takip edebilirsiniz.',
                          ],
                        );
                      },
                      icon: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                              const SizedBox(width: 6),
                              Text(
                                'XP İlerlemesi',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Flexible(
                            child: Text(
                              '${user['xp']} / 600',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: user['xp'] / 600,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06b6d4)),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sonraki seviyeye ${600 - user['xp']} XP kaldı',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.emoji_events,
            value: user['totalWords'].toString(),
            label: 'Toplam\nKelime',
            gradient: const LinearGradient(
              colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.whatshot,
            value: user['streak'].toString(),
            label: 'Gün\nSerisi',
            gradient: const LinearGradient(
              colors: [Color(0xFF22d3ee), Color(0xFF3b82f6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            value: user['weeklyXP'].toString(),
            label: 'Bu Hafta\nXP',
            gradient: const LinearGradient(
              colors: [Color(0xFF3b82f6), Color(0xFF06b6d4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Gradient gradient,
  }) {
    return Container(
      height: 150, // Sabit yükseklik ile eşit boy
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Dikeyde eşit dağılım
        children: [
          Icon(icon, color: Colors.white, size: 28),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoal() {
    final percentage = (user['learnedToday'] / user['dailyGoal'] * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Günlük Hedef',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user['learnedToday']} / ${user['dailyGoal']} kelime öğrenildi',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF22d3ee), Color(0xFF3b82f6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3306b6d4),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: user['learnedToday'] / user['dailyGoal'],
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06b6d4)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF22d3ee), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Haftalık Aktivite',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: calendar.map((day) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                        day['day'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: day['learned']
                              ? const LinearGradient(
                                  colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: day['learned'] ? null : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: day['learned']
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: day['learned']
                              ? Text(
                                  '${day['count']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı Erişim',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Konuşma',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22d3ee), Color(0xFF3b82f6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => widget.onNavigate('speaking'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.repeat,
                  label: 'Tekrar',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3b82f6), Color(0xFF06b6d4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => widget.onNavigate('repeat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.menu_book,
                  label: 'Sözlük',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => widget.onNavigate('dictionary'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineUsers() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.people, color: Color(0xFF22d3ee), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Biriyle Konuş',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${onlineUsers.length} Çevrimiçi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Diğer kullanıcılarla İngilizce pratiği yapın ve arkadaşlar edinin!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatListPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Eşleş', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          const SizedBox(height: 24),
          ...onlineUsers.map((user) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF475569).withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: Row(
                children: [
                  // SABİT: Avatar - 38px
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF22d3ee), Color(0xFF3b82f6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              user['avatar'],
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF475569),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ESNEK: Kullanıcı Bilgisi
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Seviye ${user['level']}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // SABİT: Butonlar - Padding reduced
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF64748b),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Ara',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatDetailPage(
                                name: user['name'],
                                avatar: user['avatar'],
                                status: user['status'],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06b6d4), Color(0xFF0ea5e9)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Mesaj Gönder',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentlyLearned() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Son Öğrenilenler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 16),
          // Example Dummy Data matching image. In real app, use recently learned words.
          _buildLearnedWordItem('Eloquent', 'Belagatlı, açık sözlü', 'Adjective', true),
          const SizedBox(height: 12),
          _buildLearnedWordItem('Perseverance', 'Azim, sebat', 'Noun', true),
          const SizedBox(height: 12),
          _buildLearnedWordItem('Gregarious', 'Sosyal, cana yakın', 'Adjective', true),
          const SizedBox(height: 12),
          _buildLearnedWordItem('Ephemeral', 'Geçici, kısa ömürlü', 'Adjective', false),
        ],
      ),
    );
  }

  Widget _buildLearnedWordItem(String word, String meaning, String type, bool isFavorite) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    word,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isFavorite) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.favorite, color: Colors.pinkAccent, size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                meaning,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              type,
              style: const TextStyle(
                color: Colors.cyan,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
