import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_page.dart';
import 'screens/repeat_page.dart';
import 'screens/dictionary_page.dart';
import 'screens/words_page.dart';
import 'screens/sentences_page.dart';
import 'screens/menu_page.dart';
import 'screens/practice_page.dart';
import 'screens/stats_page.dart';
import 'screens/speaking_page.dart';
import 'screens/review_page.dart';
import 'screens/quick_dictionary_page.dart';
import 'screens/chat_list_page.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/animated_background.dart';
import 'widgets/animated_background.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_page.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/global_state.dart';
import 'widgets/global_matching_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const VocabMasterApp());
}

class VocabMasterApp extends StatelessWidget {
  const VocabMasterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VocabMaster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'Inter',
      ),
      home: const OnboardingScreen(),
      builder: (context, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: GlobalState.isMatching,
          builder: (context, isMatching, _) {
            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: isMatching ? 70 : 0, // Push content up
                  child: child!,
                ),
                if (isMatching)
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Material(
                      type: MaterialType.transparency,
                      child: SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.cyan),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }
  String? _practiceInitialMode;

  void _onNavigate(String page) {
    switch (page) {
      case 'speaking':
        // Navigate to speaking page
        break;
      case 'repeat':
        // If repeat is requested from home, go to Practice tab (index 4)
        setState(() => _currentIndex = 4);
        break;
      case 'dictionary':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DictionaryPage()),
        );
        break;
      case 'words':
        setState(() => _currentIndex = 1);
        break;
      case 'sentences':
        setState(() => _currentIndex = 3);
        break;
    }
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return HomePage(onNavigate: _onNavigate);
      case 1:
        return const WordsPage();
      case 2:
        return const MenuPage();
      case 3:
        return const SentencesPage();
      case 4:
        return PracticePage(initialMode: _practiceInitialMode);
      default:
        return HomePage(onNavigate: _onNavigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Open drawer when Menu is tapped
            _scaffoldKey.currentState?.openDrawer();
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Animated Background
          const AnimatedBackground(isDark: true),
          
          // Content
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1e3a8a).withOpacity(0.8),
                      const Color(0xFF1e40af).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VocabMaster',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Navigasyon Menüsü',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.white54),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          
          // Main Pages Section
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Text(
                    'ANA SAYFALAR',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Profil',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.home,
                  title: 'Ana Sayfa',
                  isSelected: _currentIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.book,
                  title: 'Kelimeler',
                  isSelected: _currentIndex == 1,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.text_fields,
                  title: 'Cümleler',
                  isSelected: _currentIndex == 3,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 3);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.school,
                  title: 'Pratik',
                  isSelected: _currentIndex == 4,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 4);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.chat_bubble,
                  title: 'Sohbet',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatListPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bar_chart,
                  title: 'İstatistikler',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StatsPage()),
                    );
                  },
                ),
                
                const Divider(color: Colors.white24, height: 40),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Text(
                    'ÖZEL SAYFALAR',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Konuşma',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentIndex = 4;
                      _practiceInitialMode = 'Konuşma';
                    });
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.replay,
                  title: 'Tekrar',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReviewPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.book,
                  title: 'Sözlük',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuickDictionaryPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),
                Text(
                  'VocabMaster v1.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '© 2026 Tüm Hakları Saklıdır',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4), // Reduce vertical size
        leading: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
